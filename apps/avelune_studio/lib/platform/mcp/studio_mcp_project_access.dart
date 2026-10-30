import 'dart:io';

import 'package:flutter/services.dart';

Future<String?> createStudioMcpProjectBookmark(String root) async {
  if (!Platform.isMacOS) return null;
  return const MethodChannel('map_editor/file_access')
      .invokeMethod<String>('createMcpProjectBookmark', {'path': root});
}
