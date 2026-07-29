import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/assets/editor_image_cache.dart';

final editorImageCacheProvider =
    Provider.autoDispose.family<EditorImageCache, String>((ref, projectRoot) {
  final cache = EditorImageCache(sessionKey: projectRoot);
  ref.onDispose(cache.dispose);
  return cache;
});
