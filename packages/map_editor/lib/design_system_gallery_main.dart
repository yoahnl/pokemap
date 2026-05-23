import 'package:flutter/material.dart';
import 'src/theme/theme.dart';
import 'src/ui/design_system/gallery/pokemap_design_system_gallery.dart';

void main() {
  // Ensure the binding is initialized at the absolute beginning of main()
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const PokeMapDesignSystemGalleryApp());
}

/// Root widget for the isolated PokeMap Design System Component Gallery.
class PokeMapDesignSystemGalleryApp extends StatelessWidget {
  const PokeMapDesignSystemGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeMap Design System Gallery',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      builder: (context, child) {
        return PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const PokeMapDesignSystemGallery(),
    );
  }
}
