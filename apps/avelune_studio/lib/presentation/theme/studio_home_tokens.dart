import 'package:flutter/material.dart';

abstract final class StudioHomeTokens {
  static Color titleAccent(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.light
        ? theme.colorScheme.primary
        : const Color(0xff81baff);
  }
}
