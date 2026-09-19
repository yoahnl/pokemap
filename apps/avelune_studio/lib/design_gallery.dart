import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/gallery/studio_widget_gallery.dart';
import 'presentation/theme/studio_theme.dart';

void main() => runApp(const StudioDesignGalleryApp());

class StudioDesignGalleryApp extends StatelessWidget {
  const StudioDesignGalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Avelune Studio — Catalogue des widgets',
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const StudioWidgetGallery(),
  );
}
