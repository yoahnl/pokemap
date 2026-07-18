import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

const narrativeStudioCaptureFontAsset =
    'assets/fonts/pokemap_capture_sans_regular.ttf';

final Set<String> _loadedTextFamilies = <String>{};
bool _cupertinoIconsLoaded = false;
bool _materialIconsLoaded = false;

/// Loads the repository-versioned capture font and bundled framework icons.
///
/// Golden tests may register the same text bytes under the family names used
/// by their existing themes. This keeps the pixels deterministic without
/// depending on host fonts or Flutter's internal cache layout.
Future<void> loadNarrativeStudioCaptureFonts({
  required Iterable<String> textFamilies,
}) async {
  final pendingTextFamilies = textFamilies
      .where((family) => family.trim().isNotEmpty)
      .where((family) => !_loadedTextFamilies.contains(family))
      .toSet();
  if (pendingTextFamilies.isNotEmpty) {
    final textFontBytes = await rootBundle.load(
      narrativeStudioCaptureFontAsset,
    );
    for (final family in pendingTextFamilies) {
      final loader = FontLoader(family)
        ..addFont(Future<ByteData>.value(textFontBytes));
      await loader.load();
      _loadedTextFamilies.add(family);
    }
  }

  if (!_cupertinoIconsLoaded) {
    final iconFontBytes = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    final effectiveIconFamily = const TextStyle(
      fontFamily: CupertinoIcons.iconFont,
      package: CupertinoIcons.iconFontPackage,
    ).fontFamily!;
    final loader = FontLoader(effectiveIconFamily)
      ..addFont(Future<ByteData>.value(iconFontBytes));
    await loader.load();
    _cupertinoIconsLoaded = true;
  }

  if (!_materialIconsLoaded) {
    final iconFontBytes = await rootBundle.load(
      'fonts/MaterialIcons-Regular.otf',
    );
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(iconFontBytes));
    await loader.load();
    _materialIconsLoaded = true;
  }
}
